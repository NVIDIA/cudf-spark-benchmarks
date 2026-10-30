WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        rs.total_avail_qty,
        rs.total_supply_cost,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 10
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_name,
    ts.nation_name,
    os.o_orderkey,
    os.o_orderdate,
    os.revenue,
    ts.total_avail_qty,
    ts.total_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    OrderStats os ON ts.s_suppkey IN (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        WHERE 
            ps.ps_partkey IN (
                SELECT 
                    p.p_partkey 
                FROM 
                    part p 
                WHERE 
                    p.p_size > 10
            )
    )
ORDER BY 
    os.revenue DESC, ts.total_avail_qty ASC;