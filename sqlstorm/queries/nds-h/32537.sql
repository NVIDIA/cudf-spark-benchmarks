WITH  OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SalesSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
TopSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
    JOIN 
        part p ON ss.p_partkey = p.p_partkey
)
SELECT 
    th.p_partkey,
    th.p_name,
    th.total_sales,
    th.order_count,
    oh.customer_name,
    oh.o_orderdate
FROM 
    TopSales th
LEFT JOIN 
    OrderHierarchy oh ON th.order_count = oh.rank
WHERE 
    th.sales_rank <= 10
  AND 
    EXISTS (SELECT 1 FROM lineitem l WHERE l.l_discount = 0.05 AND l.l_partkey = th.p_partkey)
ORDER BY 
    th.total_sales DESC, oh.o_orderdate DESC;
