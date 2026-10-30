WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rn.r_name AS region,
    rn.n_name AS nation,
    ss.s_name AS supplier_name,
    COALESCE(od.total_order_value, 0) AS total_order_value,
    ss.total_available_quantity,
    ss.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY rn.n_name ORDER BY ss.total_supply_cost DESC) AS supplier_rank
FROM 
    RegionNation rn
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_type = 'FURNITURE' AND p.p_size > 10
        )
    )
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' AND o.o_orderstatus = 'O'
    )
WHERE 
    ss.total_available_quantity IS NOT NULL OR od.total_order_value IS NOT NULL
ORDER BY 
    rn.r_name, total_order_value DESC;