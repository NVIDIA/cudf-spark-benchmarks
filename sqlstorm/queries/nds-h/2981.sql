WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1995-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sd.total_supply_cost,
           RANK() OVER (ORDER BY sd.total_supply_cost DESC) as supplier_rank
    FROM supplier s
    JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
    WHERE sd.total_supply_cost > 10000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(co.total_order_value), 0) AS total_customer_spend,
           RANK() OVER (ORDER BY COALESCE(SUM(co.total_order_value), 0) DESC) as customer_rank
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT tc.c_custkey, tc.c_name, 
       ts.s_suppkey, ts.s_name,
       CASE WHEN tc.total_customer_spend IS NULL THEN 0 ELSE tc.total_customer_spend END AS total_customer_spend,
       CASE WHEN ts.total_supply_cost IS NULL THEN 'Low Supply' ELSE 'High Supply' END AS supply_status
FROM TopCustomers tc
FULL OUTER JOIN TopSuppliers ts ON tc.customer_rank = ts.supplier_rank
WHERE (tc.total_customer_spend > 5000 OR ts.total_supply_cost > 20000)
ORDER BY total_customer_spend DESC NULLS LAST, supply_status;