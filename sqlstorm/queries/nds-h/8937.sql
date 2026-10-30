
WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey
),
RankedSales AS (
    SELECT 
        ts.p_partkey,
        ts.revenue,
        RANK() OVER (ORDER BY ts.revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FinalOutput AS (
    SELECT 
        rs.revenue_rank,
        rs.revenue,
        s.s_suppkey,
        s.s_name,
        c.c_name AS customer_name,
        c.c_acctbal,
        n.n_name AS nation_name
    FROM 
        RankedSales rs
    JOIN 
        lineitem li ON rs.p_partkey = li.l_partkey
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON li.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        rs.revenue_rank <= 10
)
SELECT 
    revenue_rank,
    revenue,
    s_name,
    customer_name,
    c_acctbal,
    nation_name
FROM 
    FinalOutput
ORDER BY 
    revenue_rank;
