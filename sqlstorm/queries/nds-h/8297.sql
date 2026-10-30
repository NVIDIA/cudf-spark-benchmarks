WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_totalprice,
        r.o_orderdate,
        r.o_orderstatus,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM RankedOrders r
    JOIN lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE r.price_rank <= 10
    GROUP BY r.o_orderkey, r.o_totalprice, r.o_orderdate, r.o_orderstatus
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(h.o_orderkey) AS order_count,
        SUM(h.total_extended_price) AS total_spent
    FROM customer c
    JOIN HighValueOrders h ON c.c_custkey = h.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        coss.c_custkey,
        coss.c_name,
        coss.order_count,
        coss.total_spent,
        RANK() OVER (ORDER BY coss.total_spent DESC) AS customer_rank
    FROM CustomerOrderSummary coss
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.order_count,
    tc.total_spent
FROM TopCustomers tc
WHERE tc.customer_rank <= 5
ORDER BY tc.total_spent DESC;