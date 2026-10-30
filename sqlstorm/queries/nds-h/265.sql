
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SuppliersWithPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
), FinalReport AS (
    SELECT 
        r.r_name AS region,
        p.p_name AS part_name,
        SUM(od.total_revenue) AS revenue,
        COUNT(DISTINCT od.o_orderkey) AS order_count,
        COUNT(s.rank) AS supplier_ranking_count
    FROM 
        RankedSuppliers s
    RIGHT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        OrderDetails od ON od.o_orderkey = ps.ps_partkey
    JOIN 
        supplier sp ON sp.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON sp.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA' AND 
        (s.rank IS NULL OR s.rank <= 5)
    GROUP BY 
        r.r_name, p.p_name
)

SELECT 
    region,
    part_name,
    revenue,
    order_count,
    supplier_ranking_count,
    CASE 
        WHEN revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Available'
    END AS revenue_status
FROM 
    FinalReport
ORDER BY 
    revenue DESC, order_count ASC;
