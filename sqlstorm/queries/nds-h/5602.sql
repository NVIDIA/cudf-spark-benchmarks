
WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
), 
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
Profitability AS (
    SELECT 
        ts.p_partkey,
        ts.total_revenue,
        sd.s_suppkey,
        sd.s_name,
        sd.total_cost,
        (ts.total_revenue - sd.total_cost) AS profit
    FROM 
        TotalSales ts
    JOIN 
        SupplierDetails sd ON ts.p_partkey = sd.ps_partkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    r.r_name AS supplier_region,
    SUM(pr.profit) AS total_profit
FROM 
    Profitability pr
JOIN 
    partsupp ps ON pr.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON pr.p_partkey = p.p_partkey
GROUP BY 
    p.p_name, p.p_mfgr, r.r_name
ORDER BY 
    total_profit DESC
LIMIT 10;
