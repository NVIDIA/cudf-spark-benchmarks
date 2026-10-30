WITH  price_trends AS (
    SELECT 
        ps_partkey, 
        SUM(ps_supplycost) AS total_supply_cost, 
        COUNT(*) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY SUM(ps_supplycost) DESC) AS rank
    FROM 
        partsupp 
    GROUP BY 
        ps_partkey
), 
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
supplier_summary AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_balance,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    pt.total_supply_cost,
    pt.supplier_count,
    ho.total_order_value,
    ss.total_balance,
    ss.supplier_count AS nation_supplier_count
FROM 
    part p
LEFT JOIN 
    price_trends pt ON p.p_partkey = pt.ps_partkey
FULL OUTER JOIN 
    high_value_orders ho ON ho.total_order_value IS NOT NULL 
LEFT JOIN 
    supplier_summary ss ON ss.total_balance IS NOT NULL
WHERE 
    p.p_size = (SELECT MAX(p_size) FROM part WHERE p_retailprice < 100)
    AND (p.p_mfgr LIKE 'Manufacturer#1' OR p.p_container IS NULL)
ORDER BY 
    p.p_retailprice DESC
LIMIT 50;
