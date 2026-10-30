WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT 
        ts.p_name,
        ts.total_revenue,
        ss.supplier_revenue,
        RANK() OVER (PARTITION BY ts.p_name ORDER BY ts.total_revenue DESC) AS rank_total,
        RANK() OVER (PARTITION BY ss.s_name ORDER BY ss.supplier_revenue DESC) AS rank_supplier
    FROM 
        TotalSales ts
    JOIN 
        SupplierSales ss ON ts.total_revenue = ss.supplier_revenue
)
SELECT 
    r.p_name,
    r.total_revenue,
    r.supplier_revenue
FROM 
    RankedSales r
WHERE 
    r.rank_total = 1 AND r.rank_supplier = 1
ORDER BY 
    r.total_revenue DESC;