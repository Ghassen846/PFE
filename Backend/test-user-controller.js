// A simple test script to verify we can import the changePassword function from userController.js

import { changePassword } from './controllers/userController.js';

console.log('Successfully imported changePassword function from userController.js');
console.log('The function definition is:', changePassword.toString().substring(0, 100) + '...');
console.log('Test completed successfully - no syntax errors detected!');
