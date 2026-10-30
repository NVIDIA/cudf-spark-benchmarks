
WITH  monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o_orderdate) AS sale_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01'
    GROUP BY 
        DATE_TRUNC('month', o_orderdate)
),
ranked_sales AS (
    SELECT 
        sale_month,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        monthly_sales
),
top_months AS (
    SELECT 
        sale_month
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 3
),
supplier_info AS (
    SELECT
        s.s_suppkey,
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
),
sales_loss AS (
    SELECT DISTINCT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS lost_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l_returnflag = 'R' 
        AND o.o_orderdate < DATE_TRUNC('year', DATE '1998-10-01')
    GROUP BY 
        n.n_name
)
SELECT 
    COALESCE(r.supplier_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(ls.nation_name, 'No Nation') AS nation_name,
    COALESCE(ls.lost_sales, 0) AS lost_sales,
    ts.sale_month,
    ms.total_sales
FROM 
    supplier_info r
FULL OUTER JOIN 
    sales_loss ls ON r.part_count > 0 OR ls.lost_sales IS NOT NULL
JOIN 
    top_months ts ON ts.sale_month = DATE_TRUNC('month', DATE '1998-10-01')
JOIN 
    ranked_sales ms ON ms.sale_month = ts.sale_month
WHERE 
    r.supplier_name IS NOT NULL 
    AND (ls.lost_sales IS NULL OR ls.lost_sales > 0)
ORDER BY 
    ts.sale_month DESC, r.supplier_name;
