WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        pd.p_name,
        pd.p_brand,
        pd.p_type
    FROM 
        partsupp ps
    JOIN 
        part pd ON ps.ps_partkey = pd.p_partkey
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        SupplierDetails sd
    JOIN 
        PartSupplier ps ON sd.s_suppkey = ps.ps_suppkey
    GROUP BY 
        sd.s_suppkey, sd.s_name, sd.nation_name, sd.region_name
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
)
SELECT 
    ts.s_name,
    ts.nation_name,
    ts.region_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    lineitem l ON l.l_suppkey = ts.s_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    ts.s_name, ts.nation_name, ts.region_name
ORDER BY 
    total_revenue DESC;
