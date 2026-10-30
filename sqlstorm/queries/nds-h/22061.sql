
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderstatus IN ('O', 'F')
), SupplierParts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > 100
    GROUP BY 
        ps.ps_suppkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
    HAVING 
        SUM(o.o_totalprice) > 5000
)

SELECT 
    p.p_name,
    s.s_name,
    r.r_name,
    COALESCE(sp.total_avail_qty, 0) AS total_available_quantity,
    hvc.total_spent * 0.1 AS expected_discount,
    CASE 
        WHEN hvc.total_spent IS NULL THEN 'No Orders'
        ELSE 'Frequent Shopper'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON s.s_nationkey = hvc.c_nationkey
WHERE 
    p.p_size > (SELECT AVG(p_size) FROM part)
    AND s.s_acctbal IS NOT NULL
ORDER BY 
    customer_status DESC, 
    expected_discount DESC
LIMIT 100;
