WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size > 10
), 
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS total_line_items,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ps.p_name AS part_name,
    ps.price_rank,
    ss.total_available_qty,
    ss.average_supply_cost,
    os.total_price,
    os.total_line_items
FROM 
    RankedParts ps
JOIN 
    supplier s ON ps.p_partkey = s.s_suppkey
JOIN 
    SupplierSummary ss ON s.s_nationkey = ss.s_nationkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    OrderSummary os ON os.o_custkey = s.s_nationkey
WHERE 
    ps.price_rank <= 5
ORDER BY 
    region_name, nation_name, total_price DESC;
