WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_price,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    part p
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey AND o.rn <= 5
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, s.total_supply_cost
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0
ORDER BY 
    total_supply_cost DESC, avg_order_price ASC;