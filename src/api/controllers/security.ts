import * as express from 'express';
import { GetEndpointManager } from './endpoint_manager';

export const PreOperation = async (
  req: express.Request,
  res: express.Response,
  next: any,
) => {
  const targetEndpoint = req.query.targetEndpoint;
  try {
    if (targetEndpoint) {
      res.locals.jolokia = GetEndpointManager().getJolokia(
        targetEndpoint as string,
      );
      if (res.locals.jolokia.brokerName === '') {
        res.locals.jolokia
          .fetchBrokerName(req.token)
          .then((ret) => {
            if (ret) {
              next();
            } else {
              res.status(500);
              res.json({
                status: 'failed',
                message: 'internal error',
              });
              res.end();
            }
          })
          .catch((err) => {
            res.status(500);
            res.json({
              status: 'failed',
              message: err.statusText,
            });
            res.end();
          });
      } else {
        next();
      }
    } else {
      next();
    }
  } catch (err) {
    res.status(500);
    res.json({
      status: 'failed',
      message: 'internal error ' + err,
    });
    res.end();
  }
};
