// A simple test script to verify we can import the deliveryController without errors

import { getDeliveryStats } from './controllers/deliveryController.js';

console.log('Successfully imported getDeliveryStats function from deliveryController.js');
console.log('The function definition is:', getDeliveryStats.toString().substring(0, 100) + '...');
console.log('Test completed successfully - no syntax errors detected!');
