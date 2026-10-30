WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
),
SubquerySupplier AS (
    SELECT 
        ps.ps_partkey, 
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN SUM(o.o_totalprice) IS NULL THEN 0 
            ELSE SUM(o.o_totalprice) 
        END AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 END) > 5
),
JoinedData AS (
    SELECT 
        r.r_name,
        no.n_name AS nation_name,
        COUNT(DISTINCT co.c_custkey) AS customer_count,
        SUM(ifo.l_extendedprice * (1 - ifo.l_discount)) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation no ON r.r_regionkey = no.n_regionkey
    LEFT JOIN 
        customer co ON no.n_nationkey = co.c_nationkey
    LEFT JOIN 
        orders o ON co.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem ifo ON o.o_orderkey = ifo.l_orderkey
    GROUP BY 
        r.r_name, no.n_name
    HAVING 
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) < COUNT(o.o_orderkey)
)
SELECT 
    jd.r_name,
    jd.nation_name,
    jd.customer_count,
    CASE 
        WHEN jd.total_revenue IS NULL THEN 0
        ELSE jd.total_revenue
    END AS revenue,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM RankedOrders ro WHERE ro.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O')
        ) THEN 'Has Top Orders'
        ELSE 'No Top Orders'
    END AS order_status
FROM 
    JoinedData jd
JOIN 
    SubquerySupplier ss ON ss.p_brand = 'Brand#25'
WHERE 
    jd.customer_count > 0
ORDER BY 
    revenue DESC NULLS LAST;
