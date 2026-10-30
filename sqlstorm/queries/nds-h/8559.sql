
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
), 
HighRankedSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        supply_rank <= 3
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cos.c_name AS customer_name,
    hr.nation AS supplier_nation,
    hr.region AS supplier_region,
    hr.total_supply_cost,
    cos.total_spent,
    cos.total_orders
FROM 
    HighRankedSuppliers hr
JOIN 
    CustomerOrderSummary cos ON hr.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE 
            l.l_orderkey IN (
                SELECT 
                    o.o_orderkey 
                FROM 
                    orders o 
                WHERE 
                    o.o_orderstatus = 'F'
            ) 
        LIMIT 1
    )
ORDER BY 
    hr.total_supply_cost DESC, 
    cos.total_spent DESC;
