WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_amount,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RankedSales AS (
    SELECT 
        t.p_partkey,
        t.p_name,
        t.sales_amount,
        t.order_count,
        RANK() OVER (ORDER BY t.sales_amount DESC) AS sales_rank
    FROM 
        TotalSales t
)
SELECT 
    rs.p_partkey,
    rs.p_name,
    rs.sales_amount,
    rs.order_count,
    COALESCE(si.s_name, 'No Supplier') AS supplier_name,
    si.s_acctbal
FROM 
    RankedSales rs
LEFT JOIN 
    SupplierInfo si ON rs.p_partkey = si.s_suppkey
WHERE 
    rs.sales_rank <= 10
    AND (si.s_acctbal IS NULL OR si.s_acctbal > 1000)
ORDER BY 
    rs.sales_amount DESC;
