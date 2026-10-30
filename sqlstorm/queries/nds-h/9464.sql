WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
), 
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
), 
OrderStats AS (
    SELECT 
        o.o_orderstatus,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY 
        o.o_orderstatus
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    tp.p_name AS top_part_name,
    tp.total_supply_value,
    os.o_orderstatus,
    os.order_count,
    os.total_revenue
FROM 
    RegionStats rs
JOIN 
    TopParts tp ON tp.total_supply_value > 0
JOIN 
    OrderStats os ON os.order_count > 0
ORDER BY 
    rs.region_name, os.o_orderstatus;