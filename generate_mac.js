// 使用 Node.js 內建的 crypto 模組
const crypto = require('crypto');

function generateMac(account, enterpriseId) {
    const macString = account + enterpriseId + "jinher!@#890";
    const mac = crypto.createHash('md5').update(macString, 'utf8').digest('hex').toLowerCase();
    return mac;
}

// 新的資料
const requestData = {
    "act": "getvipandcardinfo",
    "EnterpriseID": "XF42792721",
    "Account": "0900007056",
    "AMobile": "0900007056",
    "mac": ""
};

// 生成 MAC
const mac = generateMac(requestData.Account, requestData.EnterpriseID);

// 更新請求資料
requestData.mac = mac;

console.log('計算字串:', requestData.Account + requestData.EnterpriseID + "jinher!@#890");
console.log('生成的 MAC:', mac);
console.log('完整的請求資料:', JSON.stringify(requestData, null, 2)); 