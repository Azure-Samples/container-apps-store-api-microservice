var express = require('express');
var router = express.Router();
const axios = require('axios').default;
const orderService = process.env.ORDER_SERVICE_NAME || 'python-service';
const daprPort = process.env.DAPR_HTTP_PORT || 3500;

//use dapr http proxy (header) to call orders service with normal /order route URL in axios.get call
const daprSidecar = `http://localhost:${daprPort}`
//const daprSidecar = `http://localhost:${daprPort}/v1.0/invoke/${orderService}/method`

/* GET order by calling order microservice via dapr */
router.get('/', async function(req, res, next) {

  var data = await axios.get(`${daprSidecar}/order?id=${req.query.id}`, {
    headers: {'dapr-app-id': `${orderService}`} //sets app name for service discovery
  });
  
  res.send(`${JSON.stringify(data.data)}`);
});

/* POST create order by calling order microservice via dapr */
router.post('/', async function(req, res, next) {
  try{
    var order = req.body;
    order['location'] = 'Seattle';
    order['priority'] = 'Standard';
    var data = await axios.post(`${daprSidecar}/order?id=${req.query.id}`, order, {
      headers: {'dapr-app-id': `${orderService}`} //sets app name for service discovery
    });
  
    res.send(`<p>Order created!</p><br/><code>${JSON.stringify(data.data)}</code>`);
  }
  catch(err){
    res.send(`<p>Error creating order<br/>Order microservice or dapr may not be running.<br/></p><br/><code>${err}</code>`);
  }
});

module.exports = router;
