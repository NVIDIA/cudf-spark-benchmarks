WITH  RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 month'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        rnk, 
        rs.s_name, 
        ro.total_revenue,
        CASE 
            WHEN ro.total_revenue IS NULL THEN 'No Sales'
            ELSE 'Sales Present'
        END AS sales_status
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        RecentOrders ro ON rs.s_suppkey = ro.o_orderkey 
    WHERE 
        rs.rnk <= 10
    ORDER BY 
        rs.total_cost DESC
)
SELECT 
    s.s_name, 
    COALESCE(sp.total_revenue, 0) AS total_revenue, 
    sp.sales_status,
    CASE 
        WHEN sp.sales_status = 'Sales Present' THEN 'Active Supplier'
        ELSE 'Inactive Supplier'
    END AS supplier_status
FROM 
    SupplierPerformance sp
RIGHT JOIN 
    supplier s ON sp.s_name = s.s_name
WHERE 
    s.s_comment LIKE '%important%' OR sp.sales_status IS NULL
ORDER BY 
    total_revenue DESC;