WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_sales,
        r.order_count
    FROM 
        RankedSuppliers r
    WHERE 
        r.sales_rank <= 10
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS customer_total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name, r.r_name
)
SELECT 
    tr.s_name AS supplier_name,
    cr.nation_name,
    cr.region_name,
    cr.customer_total_spent,
    COALESCE(tr.order_count, 0) AS orders_placed
FROM 
    TopSuppliers tr
FULL OUTER JOIN 
    CustomerRegion cr ON tr.s_suppkey = cr.c_custkey
WHERE 
    (cr.customer_total_spent IS NOT NULL OR tr.order_count IS NOT NULL)
ORDER BY 
    supplier_name, region_name;