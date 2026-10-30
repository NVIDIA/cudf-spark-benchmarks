WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 20.00
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), 
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
), 
SupplierOrderCount AS (
    SELECT 
        l.l_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_returnflag = 'R'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    s.s_name,
    s.s_acctbal,
    hp.p_name,
    hp.total_value AS part_value,
    os.total_sales,
    os.line_item_count,
    soc.order_count
FROM 
    RankedSuppliers s
LEFT JOIN 
    HighValueParts hp ON s.rnk <= 5
JOIN 
    OrderStatistics os ON os.total_sales > 50000
LEFT JOIN 
    SupplierOrderCount soc ON s.s_suppkey = soc.l_suppkey
WHERE 
    s.rnk <= 10 OR soc.order_count IS NULL
ORDER BY 
    s.s_acctbal DESC, hp.total_value DESC;