WITH  SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, p.p_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(os.total_order_value) AS total_value,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(CASE 
            WHEN c.c_acctbal IS NOT NULL THEN c.c_acctbal 
            ELSE 0 
        END) AS avg_account_balance,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    CASE 
        WHEN SUM(s.s_acctbal) > 1000000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS supplier_value_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    OrderSummary os ON os.o_custkey = c.c_custkey
LEFT JOIN 
    SupplierCTE s ON s.p_partkey IN (SELECT part.p_partkey FROM part part)
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_value DESC
LIMIT 10;