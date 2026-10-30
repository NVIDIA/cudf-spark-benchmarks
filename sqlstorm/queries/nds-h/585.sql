
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierCostSummary AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    c.c_name,
    c.order_count,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        WHEN c.total_spent > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_segment,
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice
FROM 
    CustomerOrders c
LEFT JOIN 
    SupplierCostSummary s ON c.order_count > 5
LEFT JOIN 
    RankedOrders r ON r.rnk = 1 AND r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    c.c_acctbal > 0 OR (s.total_supply_cost BETWEEN 1000 AND 5000)
ORDER BY 
    total_spent DESC, r.o_orderdate ASC
LIMIT 10;
