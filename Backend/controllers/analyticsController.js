import Delivery from '../models/Delivery.js';
import Order from '../models/Order.js';
import User from '../models/User.js';
import Restaurant from '../models/Restaurant.js';

/**
 * Get general analytics data
 * @route   GET /api/analytics
 * @access  Private/Admin
 */
export const getAnalytics = async (req, res) => {
  try {
    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));
    
    // Get counts for today
    const [
      todayOrdersCount,
      todayDeliveriesCount,
      todayRevenue,
      totalUsers,
      totalRestaurants,
      totalOrders,
      totalRevenue
    ] = await Promise.all([
      Order.countDocuments({ createdAt: { $gte: startOfDay, $lte: endOfDay } }),
      Delivery.countDocuments({ createdAt: { $gte: startOfDay, $lte: endOfDay } }),
      Order.aggregate([
        { $match: { createdAt: { $gte: startOfDay, $lte: endOfDay } } },
        { $group: { _id: null, total: { $sum: '$totalPrice' } } }
      ]),
      User.countDocuments(),
      Restaurant.countDocuments(),
      Order.countDocuments(),
      Order.aggregate([
        { $group: { _id: null, total: { $sum: '$totalPrice' } } }
      ])
    ]);

    // Get orders and revenue by date for the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const ordersByDate = await Order.aggregate([
      { 
        $match: { 
          createdAt: { $gte: thirtyDaysAgo } 
        } 
      },
      {
        $group: {
          _id: { 
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' }
          },
          count: { $sum: 1 },
          revenue: { $sum: '$totalPrice' }
        }
      },
      { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
    ]);

    // Format the date data for the chart
    const chartData = ordersByDate.map(item => ({
      date: `${item._id.year}-${item._id.month.toString().padStart(2, '0')}-${item._id.day.toString().padStart(2, '0')}`,
      orders: item.count,
      revenue: item.revenue
    }));

    res.json({
      todayStats: {
        orders: todayOrdersCount,
        deliveries: todayDeliveriesCount,
        revenue: todayRevenue.length > 0 ? todayRevenue[0].total : 0
      },
      totalStats: {
        users: totalUsers,
        restaurants: totalRestaurants,
        orders: totalOrders,
        revenue: totalRevenue.length > 0 ? totalRevenue[0].total : 0
      },
      chartData
    });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({ error: 'Failed to fetch analytics data' });
  }
};

/**
 * Get delivery-specific analytics
 * @route   GET /api/analytics/delivery
 * @access  Private/Admin
 */
export const getDeliveryAnalytics = async (req, res) => {
  try {
    // Calculate average delivery time (in minutes)
    const avgDeliveryTime = await Delivery.aggregate([
      {
        $match: {
          status: 'completed',
          startTime: { $exists: true },
          endTime: { $exists: true }
        }
      },
      {
        $project: {
          deliveryTime: { 
            $divide: [
              { $subtract: ['$endTime', '$startTime'] },
              60000 // Convert ms to minutes
            ]
          }
        }
      },
      {
        $group: {
          _id: null,
          avgTime: { $avg: '$deliveryTime' }
        }
      }
    ]);

    // Get deliveries per day for the last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const deliveriesPerDay = await Delivery.aggregate([
      { 
        $match: { 
          createdAt: { $gte: sevenDaysAgo } 
        } 
      },
      {
        $group: {
          _id: { 
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' }
          },
          count: { $sum: 1 },
          completed: { 
            $sum: { 
              $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] 
            } 
          }
        }
      },
      { 
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } 
      }
    ]);

    // Calculate completion rate
    const deliveryStatuses = await Delivery.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);
    
    const statusCounts = deliveryStatuses.reduce((acc, status) => {
      acc[status._id] = status.count;
      return acc;
    }, {});
    
    const totalDeliveries = Object.values(statusCounts).reduce((sum, count) => sum + count, 0);
    const completedDeliveries = statusCounts.completed || 0;
    const completionRate = totalDeliveries > 0 ? (completedDeliveries / totalDeliveries) * 100 : 0;

    // Get delivery heatmap data (sample locations for demonstration)
    // In a real implementation, you would aggregate actual coordinates from your data
    const deliveryHeatMap = await Delivery.aggregate([
      {
        $match: {
          status: 'completed',
          'location.lat': { $exists: true },
          'location.lng': { $exists: true }
        }
      },
      {
        $project: {
          lat: '$location.lat',
          lng: '$location.lng',
          count: 1
        }
      },
      {
        $group: {
          _id: {
            lat: { $round: ['$lat', 3] },
            lng: { $round: ['$lng', 3] }
          },
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          _id: 0,
          lat: '$_id.lat',
          lng: '$_id.lng',
          count: 1
        }
      }
    ]);

    // Format the delivery per day data for the chart
    const formattedDeliveriesPerDay = deliveriesPerDay.map(item => ({
      date: `${item._id.year}-${item._id.month.toString().padStart(2, '0')}-${item._id.day.toString().padStart(2, '0')}`,
      total: item.count,
      completed: item.completed,
      completionRate: item.count > 0 ? (item.completed / item.count) * 100 : 0
    }));

    res.json({
      avgDeliveryTime: avgDeliveryTime.length > 0 ? Math.round(avgDeliveryTime[0].avgTime * 10) / 10 : 0,
      deliveriesPerDay: formattedDeliveriesPerDay,
      statusCounts,
      completionRate: Math.round(completionRate * 10) / 10,
      deliveryHeatMap
    });
  } catch (error) {
    console.error('Delivery analytics error:', error);
    res.status(500).json({ error: 'Failed to fetch delivery analytics data' });
  }
};