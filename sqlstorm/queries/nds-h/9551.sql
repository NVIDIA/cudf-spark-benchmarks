
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
),
RegionNation AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice
    HAVING 
        COUNT(l.l_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.total_supply_cost,
    rnn.region_name,
    rnn.nation_name,
    od.o_orderkey,
    od.o_totalprice
FROM 
    RankedParts rp
JOIN 
    RegionNation rnn ON rp.p_brand = rnn.nation_name
JOIN 
    OrderDetails od ON rp.p_partkey = od.o_orderkey
ORDER BY 
    rp.total_supply_cost DESC, rnn.region_name, od.o_totalprice DESC;
