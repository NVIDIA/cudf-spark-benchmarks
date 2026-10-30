
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPartSummary AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c 
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal >= 1000
),
TopSellingParts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    p.p_name,
    p.p_brand,
    r.total_available,
    r.total_supply_cost,
    c.nation_name,
    ts.total_revenue
FROM 
    part p
LEFT JOIN 
    SupplierPartSummary r ON p.p_partkey = r.ps_partkey
LEFT JOIN 
    TopSellingParts ts ON p.p_partkey = ts.l_partkey
JOIN 
    CustomerNation c ON c.c_custkey IN (
        SELECT 
            o.o_custkey
        FROM 
            orders o
        WHERE 
            o.o_orderkey IN (
                SELECT o_orderkey FROM RankedOrders WHERE order_rank <= 5
            )
    ) 
WHERE 
    p.p_retailprice IS NOT NULL
    AND r.total_supply_cost IS NOT NULL
ORDER BY 
    ts.total_revenue DESC NULLS LAST;
