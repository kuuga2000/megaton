# Magento 2.4.9 API Book

Local base URL:

```text
http://localhost:8081
```

REST base:

```text
http://localhost:8081/rest/V1
```

GraphQL endpoint:

```text
http://localhost:8081/graphql
```

## API Types

- Admin API: requires admin bearer token. Use for products, categories, orders, configuration, catalog management.
- Customer API: requires customer bearer token. Use for customer profile and customer cart.
- Guest API: no token. Use for public catalog, guest customer registration, guest cart.
- GraphQL API: many catalog/cart operations work as guest; customer-only queries need customer bearer token.
- SOAP, Async REST, Bulk REST: available for legacy or integration workflows.

## Admin API

Admin APIs require:

```http
Authorization: Bearer ADMIN_ACCESS_TOKEN
```

### Get Admin Token

Endpoint:

```http
POST /rest/V1/integration/admin/token
```

Payload:

```json
{
  "username": "admin",
  "password": "Admin123!"
}
```

curl:

```sh
curl -sS -X POST \
  http://localhost:8081/rest/V1/integration/admin/token \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"Admin123!"}'
```

Response:

```json
"ADMIN_ACCESS_TOKEN"
```

### Admin: Create Product

Endpoint:

```http
POST /rest/V1/products
```

Payload:

```json
{
  "product": {
    "sku": "demo-simple-001",
    "name": "Demo Simple Product",
    "attribute_set_id": 4,
    "price": 19.99,
    "status": 1,
    "visibility": 4,
    "type_id": "simple",
    "weight": 1,
    "extension_attributes": {
      "stock_item": {
        "qty": 100,
        "is_in_stock": true
      }
    },
    "custom_attributes": [
      {
        "attribute_code": "description",
        "value": "Created from REST API."
      },
      {
        "attribute_code": "short_description",
        "value": "REST API demo product."
      },
      {
        "attribute_code": "tax_class_id",
        "value": "2"
      }
    ]
  }
}
```

curl:

```sh
curl -sS -X POST http://localhost:8081/rest/V1/products \
  -H 'Authorization: Bearer ADMIN_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d @payload-product-create.json
```

Response:

```json
{
  "id": 2047,
  "sku": "demo-simple-001",
  "name": "Demo Simple Product",
  "price": 19.99,
  "status": 1,
  "visibility": 4,
  "type_id": "simple"
}
```

### Admin: Update Product

Endpoint:

```http
PUT /rest/V1/products/:sku
```

Payload:

```json
{
  "product": {
    "sku": "demo-simple-001",
    "name": "Demo Simple Product Updated",
    "price": 24.99
  }
}
```

Response:

```json
{
  "id": 2047,
  "sku": "demo-simple-001",
  "name": "Demo Simple Product Updated",
  "price": 24.99
}
```

### Admin: Delete Product

Endpoint:

```http
DELETE /rest/V1/products/:sku
```

curl:

```sh
curl -sS -X DELETE http://localhost:8081/rest/V1/products/demo-simple-001 \
  -H 'Authorization: Bearer ADMIN_ACCESS_TOKEN'
```

Response:

```json
true
```

### Admin: Create Category

Endpoint:

```http
POST /rest/V1/categories
```

Payload:

```json
{
  "category": {
    "parent_id": 2,
    "name": "API Demo Category",
    "is_active": true,
    "include_in_menu": true
  }
}
```

Response:

```json
{
  "id": 43,
  "parent_id": 2,
  "name": "API Demo Category",
  "is_active": true
}
```

### Admin: Orders

Endpoint:

```http
GET /rest/V1/orders?searchCriteria[pageSize]=5
```

Response:

```json
{
  "items": [
    {
      "entity_id": 1,
      "increment_id": "000000001",
      "status": "pending",
      "grand_total": 34,
      "customer_email": "customer@example.com"
    }
  ],
  "total_count": 1
}
```

Get one order:

```http
GET /rest/V1/orders/:id
```

## Customer API

Customer APIs require:

```http
Authorization: Bearer CUSTOMER_ACCESS_TOKEN
```

### Get Customer Token

Endpoint:

```http
POST /rest/V1/integration/customer/token
```

Payload:

```json
{
  "username": "customer@example.com",
  "password": "CustomerPassword123!"
}
```

Response:

```json
"CUSTOMER_ACCESS_TOKEN"
```

### Customer: Profile

Endpoint:

```http
GET /rest/V1/customers/me
```

Response:

```json
{
  "id": 1,
  "email": "customer@example.com",
  "firstname": "Demo",
  "lastname": "Customer"
}
```

### Customer: Create Or Get Cart

Endpoint:

```http
POST /rest/V1/carts/mine
```

Response:

```json
1
```

### Customer: Add Item To Cart

Endpoint:

```http
POST /rest/V1/carts/mine/items
```

Payload:

```json
{
  "cartItem": {
    "sku": "24-MB01",
    "qty": 1,
    "quote_id": "1"
  }
}
```

Response:

```json
{
  "item_id": 1,
  "sku": "24-MB01",
  "qty": 1,
  "name": "Joust Duffle Bag",
  "price": 34
}
```

### Customer: Cart Totals

Endpoint:

```http
GET /rest/V1/carts/mine/totals
```

Response:

```json
{
  "grand_total": 34,
  "subtotal": 34,
  "items_qty": 1,
  "base_currency_code": "USD",
  "quote_currency_code": "USD"
}
```

## Guest API

Guest APIs do not require a token.

### Guest: Store Websites

Endpoint:

```http
GET /rest/V1/store/websites
```

Response:

```json
[
  {
    "id": 1,
    "code": "base",
    "name": "Main Website",
    "default_group_id": 1
  }
]
```

### Guest: Product List

Endpoint:

```http
GET /rest/V1/products?searchCriteria[pageSize]=5
```

curl:

```sh
curl -sS 'http://localhost:8081/rest/V1/products?searchCriteria[pageSize]=5'
```

Response:

```json
{
  "items": [
    {
      "id": 1,
      "sku": "24-MB01",
      "name": "Joust Duffle Bag",
      "attribute_set_id": 15,
      "price": 34,
      "status": 1,
      "visibility": 4,
      "type_id": "simple"
    }
  ],
  "total_count": 1
}
```

### Guest: Product By SKU

Endpoint:

```http
GET /rest/V1/products/:sku
```

Example:

```sh
curl -sS http://localhost:8081/rest/V1/products/24-MB01
```

Response:

```json
{
  "id": 1,
  "sku": "24-MB01",
  "name": "Joust Duffle Bag",
  "price": 34,
  "type_id": "simple",
  "status": 1,
  "visibility": 4
}
```

### Guest: Categories

Endpoint:

```http
GET /rest/V1/categories
```

Response:

```json
{
  "id": 2,
  "parent_id": 1,
  "name": "Default Category",
  "is_active": true,
  "children_data": []
}
```

### Guest: Create Customer

Endpoint:

```http
POST /rest/V1/customers
```

Payload:

```json
{
  "customer": {
    "email": "customer@example.com",
    "firstname": "Demo",
    "lastname": "Customer",
    "website_id": 1
  },
  "password": "CustomerPassword123!"
}
```

Response:

```json
{
  "id": 1,
  "group_id": 1,
  "email": "customer@example.com",
  "firstname": "Demo",
  "lastname": "Customer",
  "website_id": 1
}
```

### Guest: Create Cart

Endpoint:

```http
POST /rest/V1/guest-carts
```

Response:

```json
"GUEST_CART_ID"
```

### Guest: Add Item To Cart

Endpoint:

```http
POST /rest/V1/guest-carts/:cartId/items
```

Payload:

```json
{
  "cartItem": {
    "quote_id": "GUEST_CART_ID",
    "sku": "24-MB01",
    "qty": 1
  }
}
```

Response:

```json
{
  "item_id": 1,
  "sku": "24-MB01",
  "qty": 1,
  "name": "Joust Duffle Bag",
  "price": 34
}
```

### Guest: Cart Totals

Endpoint:

```http
GET /rest/V1/guest-carts/:cartId/totals
```

Response:

```json
{
  "grand_total": 34,
  "subtotal": 34,
  "items_qty": 1,
  "base_currency_code": "USD",
  "quote_currency_code": "USD"
}
```

## REST Checkout Flow

This section shows the normal buying flow from cart to order.

Use one flow:

- Guest checkout: uses `/guest-carts/:cartId/...`
- Customer checkout: uses `/carts/mine/...` and requires `CUSTOMER_ACCESS_TOKEN`

### Guest Checkout Flow

#### 1. Create Guest Cart

Endpoint:

```http
POST /rest/V1/guest-carts
```

Response:

```json
"GUEST_CART_ID"
```

#### 2. Add Product To Guest Cart

Endpoint:

```http
POST /rest/V1/guest-carts/:cartId/items
```

Payload:

```json
{
  "cartItem": {
    "quote_id": "GUEST_CART_ID",
    "sku": "24-MB01",
    "qty": 1
  }
}
```

Response:

```json
{
  "item_id": 1,
  "sku": "24-MB01",
  "qty": 1,
  "name": "Joust Duffle Bag",
  "price": 34
}
```

Save `item_id`; it is needed for update and delete.

#### 3. Update Guest Cart Item Quantity

Endpoint:

```http
PUT /rest/V1/guest-carts/:cartId/items/:itemId
```

Payload:

```json
{
  "cartItem": {
    "item_id": 1,
    "quote_id": "GUEST_CART_ID",
    "sku": "24-MB01",
    "qty": 2
  }
}
```

Response:

```json
{
  "item_id": 1,
  "sku": "24-MB01",
  "qty": 2,
  "name": "Joust Duffle Bag",
  "price": 34
}
```

#### 4. Delete Guest Cart Item

Endpoint:

```http
DELETE /rest/V1/guest-carts/:cartId/items/:itemId
```

Response:

```json
true
```

#### 5. Apply Discount Coupon

Endpoint:

```http
PUT /rest/V1/guest-carts/:cartId/coupons/:couponCode
```

Example:

```http
PUT /rest/V1/guest-carts/GUEST_CART_ID/coupons/DEMO10
```

Response:

```json
true
```

Get applied coupon:

```http
GET /rest/V1/guest-carts/:cartId/coupons
```

Remove coupon:

```http
DELETE /rest/V1/guest-carts/:cartId/coupons
```

#### 6. Estimate Shipping Methods

Endpoint:

```http
POST /rest/V1/guest-carts/:cartId/estimate-shipping-methods
```

Payload:

```json
{
  "address": {
    "region": "California",
    "region_id": 12,
    "region_code": "CA",
    "country_id": "US",
    "street": ["123 Test Street"],
    "postcode": "90001",
    "city": "Los Angeles",
    "firstname": "Demo",
    "lastname": "Customer",
    "email": "guest@example.com",
    "telephone": "1234567890"
  }
}
```

Response:

```json
[
  {
    "carrier_code": "flatrate",
    "method_code": "flatrate",
    "carrier_title": "Flat Rate",
    "method_title": "Fixed",
    "amount": 5,
    "available": true
  }
]
```

Use `carrier_code` and `method_code` in the next step.

#### 7. Select Shipping Method

Endpoint:

```http
POST /rest/V1/guest-carts/:cartId/shipping-information
```

Payload:

```json
{
  "addressInformation": {
    "shipping_address": {
      "region": "California",
      "region_id": 12,
      "region_code": "CA",
      "country_id": "US",
      "street": ["123 Test Street"],
      "postcode": "90001",
      "city": "Los Angeles",
      "firstname": "Demo",
      "lastname": "Customer",
      "email": "guest@example.com",
      "telephone": "1234567890"
    },
    "billing_address": {
      "region": "California",
      "region_id": 12,
      "region_code": "CA",
      "country_id": "US",
      "street": ["123 Test Street"],
      "postcode": "90001",
      "city": "Los Angeles",
      "firstname": "Demo",
      "lastname": "Customer",
      "email": "guest@example.com",
      "telephone": "1234567890"
    },
    "shipping_carrier_code": "flatrate",
    "shipping_method_code": "flatrate"
  }
}
```

Response:

```json
{
  "payment_methods": [
    {
      "code": "checkmo",
      "title": "Check / Money order"
    }
  ],
  "totals": {
    "grand_total": 39,
    "subtotal": 34,
    "shipping_amount": 5,
    "base_currency_code": "USD",
    "quote_currency_code": "USD"
  }
}
```

#### 8. Get Payment Methods

Endpoint:

```http
GET /rest/V1/guest-carts/:cartId/payment-methods
```

Response:

```json
[
  {
    "code": "checkmo",
    "title": "Check / Money order"
  }
]
```

#### 9. Select Payment Method Without Placing Order

Endpoint:

```http
PUT /rest/V1/guest-carts/:cartId/selected-payment-method
```

Payload:

```json
{
  "method": {
    "method": "checkmo"
  }
}
```

Response:

```json
{
  "method": "checkmo",
  "title": "Check / Money order"
}
```

This only selects payment. It does not place the order.

#### 10. Pay Now / Place Guest Order

For offline/local development payment methods like `checkmo`, "pay now" means place the order. Real card payment gateways need their own gateway payloads and tokens.

Endpoint:

```http
POST /rest/V1/guest-carts/:cartId/payment-information
```

Payload:

```json
{
  "email": "guest@example.com",
  "paymentMethod": {
    "method": "checkmo"
  },
  "billingAddress": {
    "region": "California",
    "region_id": 12,
    "region_code": "CA",
    "country_id": "US",
    "street": ["123 Test Street"],
    "postcode": "90001",
    "city": "Los Angeles",
    "firstname": "Demo",
    "lastname": "Customer",
    "email": "guest@example.com",
    "telephone": "1234567890"
  }
}
```

Response:

```json
1
```

The response is the order ID.

### Customer Checkout Flow

Customer checkout is the same idea, but endpoints use `/carts/mine/...` and require:

```http
Authorization: Bearer CUSTOMER_ACCESS_TOKEN
```

#### 1. Create Or Get Customer Cart

Endpoint:

```http
POST /rest/V1/carts/mine
```

Response:

```json
1
```

#### 2. Add Item

Endpoint:

```http
POST /rest/V1/carts/mine/items
```

Payload:

```json
{
  "cartItem": {
    "sku": "24-MB01",
    "qty": 1,
    "quote_id": "1"
  }
}
```

#### 3. Update Item

Endpoint:

```http
PUT /rest/V1/carts/mine/items/:itemId
```

Payload:

```json
{
  "cartItem": {
    "item_id": 1,
    "sku": "24-MB01",
    "qty": 2,
    "quote_id": "1"
  }
}
```

#### 4. Delete Item

Endpoint:

```http
DELETE /rest/V1/carts/mine/items/:itemId
```

Response:

```json
true
```

#### 5. Apply Coupon

Endpoint:

```http
PUT /rest/V1/carts/mine/coupons/:couponCode
```

Response:

```json
true
```

Remove coupon:

```http
DELETE /rest/V1/carts/mine/coupons
```

#### 6. Estimate Shipping

Endpoint:

```http
POST /rest/V1/carts/mine/estimate-shipping-methods
```

Payload:

```json
{
  "address": {
    "region": "California",
    "region_id": 12,
    "region_code": "CA",
    "country_id": "US",
    "street": ["123 Test Street"],
    "postcode": "90001",
    "city": "Los Angeles",
    "firstname": "Demo",
    "lastname": "Customer",
    "telephone": "1234567890"
  }
}
```

#### 7. Select Shipping

Endpoint:

```http
POST /rest/V1/carts/mine/shipping-information
```

Payload shape is the same as guest checkout, but `email` is optional because Magento knows the logged-in customer.

#### 8. Select Payment

Endpoint:

```http
PUT /rest/V1/carts/mine/selected-payment-method
```

Payload:

```json
{
  "method": {
    "method": "checkmo"
  }
}
```

#### 9. Pay Now / Place Customer Order

Endpoint:

```http
POST /rest/V1/carts/mine/payment-information
```

Payload:

```json
{
  "paymentMethod": {
    "method": "checkmo"
  },
  "billingAddress": {
    "region": "California",
    "region_id": 12,
    "region_code": "CA",
    "country_id": "US",
    "street": ["123 Test Street"],
    "postcode": "90001",
    "city": "Los Angeles",
    "firstname": "Demo",
    "lastname": "Customer",
    "telephone": "1234567890"
  }
}
```

Response:

```json
1
```

The response is the order ID.

## GraphQL Guest API

GraphQL guest requests do not need `Authorization`.

Headers:

```http
Content-Type: application/json
```

### Guest GraphQL: Product Search

Payload:

```json
{
  "query": "query { products(search: \"bag\", pageSize: 5) { total_count items { uid sku name url_key stock_status image { url label } price_range { minimum_price { regular_price { value currency } } } } } }"
}
```

Response:

```json
{
  "data": {
    "products": {
      "total_count": 14,
      "items": [
        {
          "uid": "MQ==",
          "sku": "24-MB01",
          "name": "Joust Duffle Bag",
          "url_key": "joust-duffle-bag",
          "stock_status": "IN_STOCK",
          "image": {
            "url": "http://localhost:8081/media/catalog/product/...",
            "label": "Joust Duffle Bag"
          },
          "price_range": {
            "minimum_price": {
              "regular_price": {
                "value": 34,
                "currency": "USD"
              }
            }
          }
        }
      ]
    }
  }
}
```

curl:

```sh
curl -sS -X POST http://localhost:8081/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"query { products(search: \"bag\", pageSize: 5) { total_count items { sku name } } }"}'
```

### Guest GraphQL: Categories

Payload:

```json
{
  "query": "query { categories { items { uid name level url_path children { uid name level url_path } } } }"
}
```

Response:

```json
{
  "data": {
    "categories": {
      "items": [
        {
          "uid": "Mg==",
          "name": "Default Category",
          "level": 1,
          "url_path": null,
          "children": []
        }
      ]
    }
  }
}
```

### Guest GraphQL: Create Customer

Payload:

```json
{
  "query": "mutation { createCustomerV2(input: { firstname: \"Demo\", lastname: \"GraphQL\", email: \"graphql.customer@example.com\", password: \"CustomerPassword123!\", is_subscribed: false }) { customer { firstname lastname email } } }"
}
```

Response:

```json
{
  "data": {
    "createCustomerV2": {
      "customer": {
        "firstname": "Demo",
        "lastname": "GraphQL",
        "email": "graphql.customer@example.com"
      }
    }
  }
}
```

### Guest GraphQL: Create Empty Cart

Payload:

```json
{
  "query": "mutation { createEmptyCart }"
}
```

Response:

```json
{
  "data": {
    "createEmptyCart": "CART_ID"
  }
}
```

### Guest GraphQL: Add Simple Product To Cart

Payload:

```json
{
  "query": "mutation { addSimpleProductsToCart(input: { cart_id: \"CART_ID\", cart_items: [{ data: { sku: \"24-MB01\", quantity: 1 } }] }) { cart { items { id quantity product { sku name } } prices { grand_total { value currency } } } } }"
}
```

Response:

```json
{
  "data": {
    "addSimpleProductsToCart": {
      "cart": {
        "items": [
          {
            "id": "1",
            "quantity": 1,
            "product": {
              "sku": "24-MB01",
              "name": "Joust Duffle Bag"
            }
          }
        ],
        "prices": {
          "grand_total": {
            "value": 34,
            "currency": "USD"
          }
        }
      }
    }
  }
}
```

### Guest GraphQL: Update Cart Item

Payload:

```json
{
  "query": "mutation { updateCartItems(input: { cart_id: \"CART_ID\", cart_items: [{ cart_item_id: 1, quantity: 2 }] }) { cart { items { id quantity product { sku name } } prices { grand_total { value currency } } } } }"
}
```

Response:

```json
{
  "data": {
    "updateCartItems": {
      "cart": {
        "items": [
          {
            "id": "1",
            "quantity": 2,
            "product": {
              "sku": "24-MB01",
              "name": "Joust Duffle Bag"
            }
          }
        ]
      }
    }
  }
}
```

### Guest GraphQL: Remove Cart Item

Payload:

```json
{
  "query": "mutation { removeItemFromCart(input: { cart_id: \"CART_ID\", cart_item_id: 1 }) { cart { items { id quantity product { sku name } } } } }"
}
```

Response:

```json
{
  "data": {
    "removeItemFromCart": {
      "cart": {
        "items": []
      }
    }
  }
}
```

### Guest GraphQL: Apply Coupon

Payload:

```json
{
  "query": "mutation { applyCouponToCart(input: { cart_id: \"CART_ID\", coupon_code: \"DEMO10\" }) { cart { applied_coupons { code } prices { grand_total { value currency } } } } }"
}
```

Response:

```json
{
  "data": {
    "applyCouponToCart": {
      "cart": {
        "applied_coupons": [
          {
            "code": "DEMO10"
          }
        ]
      }
    }
  }
}
```

Remove coupon:

```json
{
  "query": "mutation { removeCouponFromCart(input: { cart_id: \"CART_ID\" }) { cart { applied_coupons { code } } } }"
}
```

### Guest GraphQL: Set Shipping Address

Payload:

```json
{
  "query": "mutation { setShippingAddressesOnCart(input: { cart_id: \"CART_ID\", shipping_addresses: [{ address: { firstname: \"Demo\", lastname: \"Customer\", street: [\"123 Test Street\"], city: \"Los Angeles\", region: \"California\", region_id: 12, postcode: \"90001\", country_code: US, telephone: \"1234567890\" } }] }) { cart { shipping_addresses { firstname lastname city available_shipping_methods { carrier_code method_code carrier_title method_title amount { value currency } available } } } } }"
}
```

### Guest GraphQL: Set Billing Address

Payload:

```json
{
  "query": "mutation { setBillingAddressOnCart(input: { cart_id: \"CART_ID\", billing_address: { address: { firstname: \"Demo\", lastname: \"Customer\", street: [\"123 Test Street\"], city: \"Los Angeles\", region: \"California\", region_id: 12, postcode: \"90001\", country_code: US, telephone: \"1234567890\" } } }) { cart { billing_address { firstname lastname city } } } }"
}
```

### Guest GraphQL: Select Shipping Method

Payload:

```json
{
  "query": "mutation { setShippingMethodsOnCart(input: { cart_id: \"CART_ID\", shipping_methods: [{ carrier_code: \"flatrate\", method_code: \"flatrate\" }] }) { cart { shipping_addresses { selected_shipping_method { carrier_code method_code carrier_title method_title amount { value currency } } } } } }"
}
```

### Guest GraphQL: Select Payment Method

Payload:

```json
{
  "query": "mutation { setPaymentMethodOnCart(input: { cart_id: \"CART_ID\", payment_method: { code: \"checkmo\" } }) { cart { selected_payment_method { code title } } } }"
}
```

### Guest GraphQL: Pay Now / Place Order

Payload:

```json
{
  "query": "mutation { placeOrder(input: { cart_id: \"CART_ID\" }) { order { order_number } } }"
}
```

Response:

```json
{
  "data": {
    "placeOrder": {
      "order": {
        "order_number": "000000001"
      }
    }
  }
}

```

## GraphQL Customer API

Customer GraphQL requests require:

```http
Authorization: Bearer CUSTOMER_GRAPHQL_TOKEN
```

### Customer GraphQL: Token

Payload:

```json
{
  "query": "mutation { generateCustomerToken(email: \"graphql.customer@example.com\", password: \"CustomerPassword123!\") { token } }"
}
```

Response:

```json
{
  "data": {
    "generateCustomerToken": {
      "token": "CUSTOMER_GRAPHQL_TOKEN"
    }
  }
}
```

### Customer GraphQL: Profile

Payload:

```json
{
  "query": "query { customer { firstname lastname email } }"
}
```

Response:

```json
{
  "data": {
    "customer": {
      "firstname": "Demo",
      "lastname": "GraphQL",
      "email": "graphql.customer@example.com"
    }
  }
}
```

### Customer GraphQL: Cart

Payload:

```json
{
  "query": "query { customerCart { id total_quantity items { id quantity product { sku name } } prices { grand_total { value currency } } } }"
}
```

Response:

```json
{
  "data": {
    "customerCart": {
      "id": "CUSTOMER_CART_ID",
      "total_quantity": 1,
      "items": [
        {
          "id": "1",
          "quantity": 1,
          "product": {
            "sku": "24-MB01",
            "name": "Joust Duffle Bag"
          }
        }
      ],
      "prices": {
        "grand_total": {
          "value": 34,
          "currency": "USD"
        }
      }
    }
  }
}
```

## Other Magento APIs

### SOAP API

SOAP endpoint examples:

```text
http://localhost:8081/soap/default?wsdl&services=integrationAdminTokenServiceV1
http://localhost:8081/soap/default?wsdl
```

SOAP is useful for legacy integrations. REST and GraphQL are easier for local testing.

### Async REST API

Async REST uses `/rest/async/V1`.

Example pattern:

```http
POST /rest/async/V1/products
```

Payload shape is usually the same as the synchronous REST endpoint.

RabbitMQ is configured in this Docker stack. Consumers may need to run:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm php bin/magento queue:consumers:list
docker compose exec phpfpm php bin/magento queue:consumers:start async.operations.all
```

### Bulk REST API

Bulk REST uses `/rest/async/bulk/V1`.

Example pattern:

```http
POST /rest/async/bulk/V1/products
```

Bulk APIs are useful for import jobs or updating many entities.

## Useful Debug Commands

Flush cache:

```sh
cd /home/guosong/dev/megaton
docker compose exec phpfpm php bin/magento cache:flush
```

Reindex:

```sh
docker compose exec phpfpm php bin/magento indexer:reindex
```

Find REST API definitions:

```sh
cd /home/guosong/dev/megaton/magento2
find vendor app/code -path '*/etc/webapi.xml' -type f
```

Find GraphQL schema definitions:

```sh
cd /home/guosong/dev/megaton/magento2
find vendor app/code -path '*/etc/schema.graphqls' -type f
```
