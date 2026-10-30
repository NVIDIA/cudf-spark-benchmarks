WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice BETWEEN 100.00 AND 1000.00
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 5000.00
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(r.total_orders, 0) AS total_orders,
    COALESCE(s.total_cost, 0) AS total_cost,
    c.order_count,
    CASE 
        WHEN c.order_count IS NOT NULL THEN 'Customer Exists'
        ELSE 'No Orders'
    END AS order_status,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
FROM 
    part p
LEFT JOIN 
    (SELECT o.o_orderkey, COUNT(*) AS total_orders 
     FROM RankedOrders o GROUP BY o.o_orderkey) r ON p.p_partkey = r.o_orderkey
FULL OUTER JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    CustomerStats c ON c.c_custkey = p.p_partkey
WHERE 
    (p.p_retailprice IS NOT NULL AND p.p_size BETWEEN 1 AND 100) 
    OR (p.p_mfgr = 'Manufacturer_X' AND p.p_retailprice IS NOT NULL)
ORDER BY 
    p.p_name ASC, total_cost DESC, order_count DESC;