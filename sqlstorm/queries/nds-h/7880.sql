WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS nation_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT 
                AVG(nation_revenue) FROM (
                    SELECT 
                        SUM(l.l_extendedprice * (1 - l.l_discount)) AS nation_revenue
                    FROM 
                        nation n
                    JOIN 
                        supplier s ON n.n_nationkey = s.s_nationkey
                    JOIN 
                        partsupp ps ON s.s_suppkey = ps.ps_suppkey
                    JOIN 
                        lineitem l ON ps.ps_partkey = l.l_partkey
                    GROUP BY 
                        n.n_name
                ) AS average_revenue
        )
),
FinalReport AS (
    SELECT 
        r.r_name AS region,
        tn.n_name AS nation,
        COUNT(DISTINCT ro.o_orderkey) AS order_count,
        SUM(ro.revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON c.c_custkey = ro.o_orderkey
    JOIN 
        nation tn ON c.c_nationkey = tn.n_nationkey
    JOIN 
        region r ON tn.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank = 1
    GROUP BY 
        r.r_name, tn.n_name
)
SELECT 
    region,
    nation,
    order_count,
    total_revenue
FROM 
    FinalReport
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 10;
