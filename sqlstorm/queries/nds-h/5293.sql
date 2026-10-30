
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RankedSuppliers AS (
    SELECT 
        spd.s_suppkey,
        spd.s_name,
        spd.p_partkey,
        spd.p_name,
        spd.ps_availqty,
        spd.ps_supplycost,
        RANK() OVER (PARTITION BY spd.p_partkey ORDER BY spd.ps_supplycost ASC) AS rank
    FROM 
        SupplierPartDetails spd
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
FinalAggregation AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        SUM(spd.ps_availqty) AS total_available_qty,
        AVG(spd.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT co.o_orderkey) AS total_orders
    FROM 
        RankedSuppliers spd
    JOIN 
        nation n ON spd.s_suppkey = n.n_nationkey
    JOIN 
        CustomerOrderDetails co ON spd.s_suppkey = co.c_custkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        spd.rank = 1
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    r.r_name,
    fa.total_available_qty,
    fa.avg_supply_cost,
    fa.total_orders
FROM 
    FinalAggregation fa
JOIN 
    region r ON fa.n_nationkey = r.r_regionkey
ORDER BY 
    fa.total_orders DESC, fa.avg_supply_cost ASC;
