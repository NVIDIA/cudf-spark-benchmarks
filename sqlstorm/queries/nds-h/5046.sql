WITH RevenueByNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        n.n_name
),
SuppliersParticipation AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        sp.total_available_quantity,
        sp.total_supply_cost
    FROM 
        part p
    JOIN 
        SuppliersParticipation sp ON p.p_partkey = sp.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    rb.nation_name,
    hv.p_partkey,
    hv.p_name,
    hv.p_brand,
    hv.p_retailprice,
    rb.total_revenue,
    (hv.total_available_quantity * hv.p_retailprice) AS projected_revenue
FROM 
    RevenueByNation rb
JOIN 
    HighValueParts hv ON hv.p_partkey IN (
        SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0
    )
ORDER BY 
    rb.total_revenue DESC, hv.p_retailprice DESC
LIMIT 10;