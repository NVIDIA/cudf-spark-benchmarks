
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' 
      AND o.o_orderdate < DATE '1998-10-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
        CASE 
            WHEN SUM(ps.ps_availqty) IS NULL THEN 'No Supplies'
            ELSE 'Available Supplies'
        END AS supply_status
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost,
        sd.supply_status,
        ROW_NUMBER() OVER (ORDER BY sd.total_supply_cost DESC) AS rank
    FROM SupplierDetails sd
    WHERE sd.total_supply_cost > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL 
    GROUP BY c.c_custkey, c.c_name
),
FinalAnalysis AS (
    SELECT 
        r.o_orderkey,
        COALESCE(co.total_spent, 0) AS customer_spent,
        COALESCE(ts.total_supply_cost, 0) AS supplier_cost,
        CASE 
            WHEN co.order_count IS NULL THEN 'No Orders'
            WHEN ts.supply_status = 'No Supplies' THEN 'Supplier Not Available'
            ELSE 'Active Order'
        END AS order_status
    FROM RankedOrders r
    LEFT JOIN CustomerOrders co ON r.o_orderkey = co.c_custkey
    LEFT JOIN TopSuppliers ts ON r.o_orderkey = ts.s_suppkey
)
SELECT 
    fa.o_orderkey,
    fa.customer_spent,
    fa.supplier_cost,
    fa.order_status
FROM FinalAnalysis fa
WHERE fa.order_status IN ('Active Order', 'No Orders')
AND (fa.customer_spent > 0 OR fa.supplier_cost > 1000)
ORDER BY fa.o_orderkey DESC
LIMIT 100;
