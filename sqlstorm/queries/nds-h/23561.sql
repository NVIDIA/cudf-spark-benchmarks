WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 year')
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        s.s_name,
        (CASE 
            WHEN ps.ps_availqty IS NULL THEN 'N/A'
            ELSE CAST(ps.ps_availqty AS STRING)
        END) AS availability
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        lineitem li
    JOIN 
        part p ON li.l_partkey = p.p_partkey
    WHERE 
        li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        revenue DESC
    LIMIT 10
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    hc.c_name,
    hc.total_spent,
    pti.p_name,
    pti.s_name,
    pti.ps_supplycost,
    pti.availability,
    COUNT(*) OVER (PARTITION BY r.o_orderstatus) AS status_count,
    CASE 
        WHEN r.o_orderstatus = 'F' AND hc.total_spent IS NOT NULL THEN 'Follow-up Required'
        ELSE 'No Action Needed'
    END AS customer_action
FROM 
    RankedOrders r
JOIN 
    HighValueCustomers hc ON r.o_orderkey = hc.c_custkey
JOIN 
    PartSupplierInfo pti ON pti.p_partkey IN (SELECT p.p_partkey FROM TopParts p)
WHERE 
    (hc.total_spent IS NOT NULL AND hc.total_spent > (SELECT AVG(total_spent) FROM HighValueCustomers))
    OR r.o_orderstatus IS NULL
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;