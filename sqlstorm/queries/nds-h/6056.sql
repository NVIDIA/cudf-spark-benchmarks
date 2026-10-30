WITH  OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.c_name,
    od.total_revenue,
    psd.p_name,
    psd.supply_cost,
    (od.total_revenue - psd.supply_cost) AS profit_margin
FROM 
    OrderDetails od
JOIN 
    PartSupplierDetails psd ON psd.ps_partkey IN (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_suppkey IN (
            SELECT s_suppkey 
            FROM supplier 
            WHERE s_nationkey IN (
                SELECT n_nationkey 
                FROM nation 
                WHERE n_regionkey IN (
                    SELECT r_regionkey 
                    FROM region 
                    WHERE r_name = 'Asia'
                )
            )
        )
    )
ORDER BY 
    profit_margin DESC
LIMIT 100;