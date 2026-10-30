WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(CASE WHEN o.o_totalprice IS NULL THEN 0 ELSE o.o_totalprice END) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_tax,
        li.l_returnflag,
        ROW_NUMBER() OVER (PARTITION BY li.l_orderkey ORDER BY li.l_linenumber) AS line_num
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate IS NOT NULL
        AND li.l_discount < 0.1
)
SELECT 
    rs.o_orderkey,
    cp.c_name,
    sp.p_name,
    sp.total_available,
    li.l_returnflag,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
    AVG(li.l_quantity) AS avg_quantity,
    COUNT(DISTINCT li.l_orderkey) AS num_orders
FROM 
    RankedOrders rs
JOIN 
    CustomerOrders cp ON rs.o_orderkey = cp.c_custkey
LEFT JOIN 
    FilteredLineItems li ON rs.o_orderkey = li.l_orderkey
JOIN 
    SupplierParts sp ON li.l_partkey = sp.p_partkey
WHERE 
    rs.status_rank = 1
GROUP BY 
    rs.o_orderkey, cp.c_name, sp.p_name, sp.total_available, li.l_returnflag
HAVING 
    SUM(li.l_extendedprice) > 1000
ORDER BY 
    net_revenue DESC, cp.c_name ASC;