WITH SupplierDetails AS (
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
NationDetails AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name, 
        SUM(sd.total_supply_cost) AS total_cost
    FROM 
        SupplierDetails sd
    JOIN 
        nation n ON sd.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
), 
TopNations AS (
    SELECT 
        nd.n_name, 
        nd.region_name, 
        nd.total_cost,
        RANK() OVER (PARTITION BY nd.region_name ORDER BY nd.total_cost DESC) AS rank
    FROM 
        NationDetails nd
)
SELECT 
    tn.n_name, 
    tn.region_name, 
    tn.total_cost
FROM 
    TopNations tn
WHERE 
    tn.rank <= 3
ORDER BY 
    tn.region_name, tn.total_cost DESC;
