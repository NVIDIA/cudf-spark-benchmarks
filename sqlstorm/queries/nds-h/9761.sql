WITH supplier_part_counts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
top_suppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        spc.part_count
    FROM 
        supplier s
    JOIN 
        supplier_part_counts spc ON s.s_suppkey = spc.s_suppkey
    ORDER BY 
        spc.part_count DESC, 
        s.s_acctbal DESC
    LIMIT 10
),
order_info AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderstatus
),
detailed_sales AS (
    SELECT 
        oi.o_orderkey,
        oi.o_orderstatus,
        oi.total_sales,
        oi.lineitem_count,
        ts.s_name AS supplier_name,
        ts.s_acctbal AS supplier_account_balance
    FROM 
        order_info oi
    JOIN 
        top_suppliers ts ON oi.lineitem_count > 5
)
SELECT 
    ds.o_orderkey,
    ds.o_orderstatus,
    ds.total_sales,
    ds.lineitem_count,
    ds.supplier_name,
    ds.supplier_account_balance
FROM 
    detailed_sales ds
WHERE 
    ds.total_sales > 10000
ORDER BY 
    ds.total_sales DESC, 
    ds.lineitem_count DESC;