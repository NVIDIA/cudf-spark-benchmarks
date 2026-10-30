WITH  SupplyChain AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        ps.ps_availqty > 0
),
AggregatedSupply AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) 
    GROUP BY
        p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O' 
    GROUP BY
        c.c_custkey
    HAVING
        SUM(o.o_totalprice) > 1000
),
RegionStats AS (
    SELECT
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        partsupp ps ON n.n_nationkey = ps.ps_partkey
    GROUP BY
        r.r_name
)

SELECT
    sc.s_name AS supplier_name,
    sc.p_name AS part_name,
    sc.ps_availqty,
    a.total_available_qty,
    a.avg_supply_cost,
    o.total_spent,
    r.nation_count,
    r.total_supply_cost
FROM
    SupplyChain sc
JOIN
    AggregatedSupply a ON sc.p_partkey = a.p_partkey
LEFT JOIN
    HighValueOrders o ON sc.s_suppkey = o.c_custkey
LEFT JOIN
    RegionStats r ON r.nation_count IS NOT NULL
WHERE
    sc.rank = 1
ORDER BY
    a.avg_supply_cost DESC,
    o.total_spent DESC,
    r.total_supply_cost ASC;
