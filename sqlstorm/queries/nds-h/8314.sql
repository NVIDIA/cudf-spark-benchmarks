
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), CustomerNation AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        n.n_name
), PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), FinalResults AS (
    SELECT 
        cn.nation_name,
        cn.total_orders,
        cn.total_revenue,
        MAX(ps.total_supply_cost) AS highest_supply_cost
    FROM 
        CustomerNation cn
    LEFT JOIN 
        PartSupplier ps ON ps.ps_partkey = (
            SELECT 
                p.p_partkey
            FROM 
                part p 
            WHERE 
                p.p_retailprice = (SELECT MAX(p2.p_retailprice) FROM part p2)
            LIMIT 1
        )
    GROUP BY 
        cn.nation_name, cn.total_orders, cn.total_revenue
)

SELECT 
    nation_name,
    total_orders,
    total_revenue,
    highest_supply_cost
FROM 
    FinalResults
ORDER BY 
    total_revenue DESC;
