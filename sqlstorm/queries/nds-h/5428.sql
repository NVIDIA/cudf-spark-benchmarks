WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
),
FinalReport AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        sd.s_name AS supplier_name,
        sd.nation_name,
        sd.region_name,
        sd.total_supply_cost
    FROM 
        OrderSummary os
    JOIN 
        SupplierDetails sd ON os.o_orderkey % 1000 = sd.s_suppkey % 1000  
)
SELECT 
    fr.o_orderkey,
    fr.total_revenue,
    fr.supplier_name,
    fr.nation_name,
    fr.region_name,
    fr.total_supply_cost,
    RANK() OVER (ORDER BY fr.total_revenue DESC) AS revenue_rank
FROM 
    FinalReport fr
ORDER BY 
    fr.total_revenue DESC
LIMIT 100;