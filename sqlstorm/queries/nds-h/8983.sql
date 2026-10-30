WITH SupplyData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
RegionAnalysis AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(os.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        CustomerRegion cr ON r.r_regionkey = cr.n_regionkey
    JOIN 
        OrderSummary os ON cr.c_custkey = os.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    sd.p_partkey, 
    sd.p_name, 
    sd.s_suppkey, 
    sd.s_name, 
    sd.ps_availqty, 
    sd.ps_supplycost, 
    rd.region_revenue 
FROM 
    SupplyData sd
JOIN 
    RegionAnalysis rd ON sd.s_suppkey = rd.r_regionkey
WHERE 
    sd.total_value > 10000
ORDER BY 
    rd.region_revenue DESC, 
    sd.ps_supplycost ASC;
