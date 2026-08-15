"use strict";
const { CognitoJwtVerifier } = require("aws-jwt-verify");

const jwtVerifier = CognitoJwtVerifier.create({
  userPoolId: process.env.USER_POOL_ID,
  tokenUse: "access",
  clientId: process.env.CLIENT_ID,
});

exports.handler = async (event) => {
  console.log("request:", JSON.stringify(event, undefined, 2));

  // API Gateway v2 passes token in identitySource OR headers
  // The browser sends "Bearer eyJ..." — we MUST strip "Bearer " before verifying
  const authHeader = event.identitySource?.[0] || 
                     event.headers?.authorization || 
                     event.headers?.Authorization;

  if (!authHeader) {
    console.error("No authorization header");
    return { isAuthorized: false };
  }

  // Strip "Bearer " prefix — aws-jwt-verify needs ONLY the JWT token
  const jwt = authHeader.replace(/^Bearer\s+/i, "");

  console.log("Token to verify:", jwt.substring(0, 50) + "...");

  try {
    const payload = await jwtVerifier.verify(jwt);
    console.log("Access allowed. JWT payload:", payload);
    
    return {
      isAuthorized: true,
      context: {
        sub: payload.sub
      }
    };
  } catch (err) {
    console.error("Access forbidden:", err);
    return { isAuthorized: false };
  }
};