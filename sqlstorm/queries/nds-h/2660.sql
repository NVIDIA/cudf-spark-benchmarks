WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
RankedSales AS (
    SELECT 
        ts.p_partkey,
        ts.p_name,
        ts.total_revenue,
        ts.order_count,
        RANK() OVER (PARTITION BY ts.order_count ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
)
SELECT 
    r.p_partkey,
    r.p_name,
    COALESCE(r.total_revenue, 0) AS revenue,
    COALESCE(s.supplier_cost, 0) AS supplier_cost,
    CASE 
        WHEN r.revenue_rank IS NULL THEN 'No Orders'
        WHEN s.supplier_cost IS NULL THEN 'No Supplier'
        ELSE 'Active'
    END AS status
FROM 
    RankedSales r
LEFT JOIN 
    SupplierSales s ON r.p_partkey = s.ps_partkey
ORDER BY 
    r.p_partkey;