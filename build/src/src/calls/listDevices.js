const getUserList = require("../utils/getUserList");
const getCCD = require("../utils/getCCD");

/**
 * Returns a list of the existing devices, with the admin property
 *
 * @param {Object} kwargs: {}
 * @return {Object} A formated success message.
 * result:
 *
 *   [
 *     {
 *       id, <String>
 *       admin, <Boolean>
 *     },
 *     ...
 *   ]
 */
async function listDevices() {
  const userList = await getUserList();
  const ccd = getCCD();

  return userList.map(user => ({
    id: user,
    admin: ccd.some(obj => obj.cn === user),
    ip: ""
  }));
}

module.exports = listDevices;
