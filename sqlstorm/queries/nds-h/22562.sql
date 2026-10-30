
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost 
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank_in_nation = 1
),
OrdersWithDiscount AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        o.o_orderdate
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
AggregatedResults AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(owd.total_price_after_discount) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        COALESCE(NULLIF(r.r_name, 'UNKNOWN'), 'N/A') AS region_name
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrdersWithDiscount owd ON o.o_orderkey = owd.o_orderkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
)
SELECT 
    ar.c_custkey, 
    ar.c_name, 
    ar.total_order_value,
    ar.orders_count,
    COALESCE(hcs.total_supply_cost, 0) AS max_supply_cost
FROM 
    AggregatedResults ar
LEFT JOIN 
    HighCostSuppliers hcs ON ar.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_shipdate > DATE '1998-10-01' - INTERVAL '1 year'
    )
ORDER BY 
    ar.total_order_value DESC NULLS LAST, 
    ar.orders_count DESC;
