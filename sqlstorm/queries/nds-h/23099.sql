
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER(PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
AggregatedParts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerHighValue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High Value'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
TopLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY (l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_item_rank
    FROM 
        lineitem l
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_tax) AS average_tax,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 5
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container IS NOT NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, s.s_name
HAVING 
    COUNT(CASE WHEN l.l_returnflag = 'N' THEN 1 END) > 5
    AND AVG(l.l_tax) IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 10;
