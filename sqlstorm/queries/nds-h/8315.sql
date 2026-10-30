WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1994-01-01' AND l_shipdate < DATE '1995-01-01'
    GROUP BY 
        l_partkey
),
MostProfitableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ts.total_revenue,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_partkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
)
SELECT 
    mp.p_partkey,
    mp.p_name,
    mp.total_revenue,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.region_name,
    sd.ps_availqty,
    sd.ps_supplycost
FROM 
    MostProfitableParts mp
JOIN 
    SupplierDetails sd ON mp.p_partkey = sd.ps_partkey
WHERE 
    mp.revenue_rank <= 10
ORDER BY 
    mp.total_revenue DESC, sd.s_name;