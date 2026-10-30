WITH SupplierSales AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_name, s.s_acctbal
),
CustomerRegion AS (
    SELECT 
        c.c_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS customer_spending
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, n.n_name
),
RankedSales AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),
NotableCustomers AS (
    SELECT 
        cr.nation_name,
        cr.c_name,
        cr.customer_spending,
        ROW_NUMBER() OVER (PARTITION BY cr.nation_name ORDER BY cr.customer_spending DESC) AS customer_rank
    FROM 
        CustomerRegion cr
)
SELECT 
    r.r_name,
    COALESCE(ns.c_name, 'No Purchases') AS customer_name,
    COALESCE(ns.customer_spending, 0) AS customer_spending,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(rs.total_sales, 0) AS supplier_sales,
    rs.sales_rank
FROM 
    region r
LEFT JOIN 
    NotableCustomers ns ON r.r_name = ns.nation_name AND ns.customer_rank <= 3
LEFT JOIN 
    RankedSales rs ON rs.total_sales > 0
WHERE 
    r.r_regionkey IN (1, 2, 3) 
ORDER BY 
    r.r_name, rs.sales_rank, ns.customer_spending DESC;