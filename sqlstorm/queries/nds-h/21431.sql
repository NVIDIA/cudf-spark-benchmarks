
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 0)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            WHEN s.s_acctbal > 1000 THEN 'High'
            ELSE 'Low'
        END AS acctbal_category
    FROM 
        supplier s
),
OrderData AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(*) AS total_items, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey, 
        od.o_custkey, 
        od.total_items, 
        COALESCE(od.total_revenue, 0) AS revenue
    FROM 
        OrderData od
    WHERE 
        od.total_revenue > (SELECT AVG(total_revenue) FROM OrderData)
)
SELECT 
    r.n_name AS nation_name,
    p.p_name AS part_name,
    COUNT(DISTINCT hvo.o_orderkey) AS order_count,
    SUM(CASE 
            WHEN so.acctbal_category = 'High' THEN 1 
            ELSE 0 
        END) AS high_balance_suppliers,
    SUM(NULLIF(p.p_retailprice, 0)) AS total_retail_price,
    ROW_NUMBER() OVER (PARTITION BY r.n_name ORDER BY SUM(hvo.revenue) DESC) AS nation_rank
FROM 
    nation r
LEFT JOIN 
    supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierInfo so ON s.s_suppkey = so.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    RankedParts p ON ps.ps_partkey = p.p_partkey AND p.price_rank = 1
JOIN 
    HighValueOrders hvo ON so.s_suppkey = hvo.o_custkey
GROUP BY 
    r.n_name, p.p_name
HAVING 
    SUM(hvo.revenue) > 1000 AND COUNT(DISTINCT hvo.o_orderkey) > 5
ORDER BY 
    r.n_name, nation_rank DESC;
